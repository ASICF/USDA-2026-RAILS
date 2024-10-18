import React, { useState, useEffect, Fragment } from "react";
import {
  Button,
  Grid,
  Icon,
  Label,
  Accordion,
  Divider,
  Form,
  Breadcrumb,
  Table,
  Tab,
  ButtonContent,
  Radio,
} from "semantic-ui-react";
import "semantic-ui-css/semantic.min.css";

import Breadcrumbs from "../Shared/Breadcrumb";
import { Controller, useForm } from "react-hook-form";
import MessageBox from "../Shared/MessageBox";
import moment from "moment";
import axios from "axios";
import { DateInput } from "semantic-ui-calendar-react";

const EoSplitter = ({ token, projects }) => {
  const [message, setMessage] = useState(null);
  const [results, setResults] = useState([]);
  const [project, setProject] = useState(null);
  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [selected, setSelected] = useState(null);

  const {
    handleSubmit,
    reset,
    setValue,
    register,
    getValues,
    control,
    formState: { errors },
  } = useForm({
    defaultValues: {
      project: projects[0],
      flight_date: "10/12/2024",
    },
  });

  const handleChange = (e, { name, value }) => {
    setValue(name, value);
  };

  const formSubmit = (data) => {
    console.error("formSubmit", data);
    setSubmitted(true);
    setResults([]);
    setProject(null);
    setLoading(true);
    setMessage(null);

    axios
      .post(`/eo_splitter/query`, {
        authenticity_token: token,
        project: data.project,
        flight_date: moment(data.flight_date, "l").format("YYYY-MM-DD"),
      })
      .then(({ data }) => {
        console.log("submit response", data);
        setSubmitted(false);
        setLoading(false);

        if (data.pass) {
          setResults(data.results);
          setSelected(data.results[0].id);
        } else {
          setMessage({
            status: "Error",
            text: data.message,
          });
        }
      })
      .catch((err) => {
        console.log(err);
        setMessage({
          status: "Error",
          text: "Something went wrong",
        });
      });
  };

  const splitSubmit = () => {
    console.log("splitSubmit", { selected });
    if (selected) {
      setSubmitted(true);
      setLoading(true);
      setMessage(null);

      axios
        .post(`/eo_splitter/execute`, {
          authenticity_token: token,
          upload_id: selected,
        })
        .then(({ data }) => {
          console.log("submit response", data);
          setSubmitted(false);
          setLoading(false);

          if (data.pass) {
            setResults([]);
            setSelected(null);

            setMessage({
              status: "Success",
              text: data.message,
            });
          } else {
            setMessage({
              status: "Error",
              text: data.message,
            });
          }
        })
        .catch((err) => {
          console.log(err);
          setMessage({
            status: "Error",
            text: "Something went wrong",
          });
        });
    } else {
      setMessage({
        status: "Error",
        text: "Select an Upload before submitting",
      });
    }
  };

  const renderMessage = () => {
    if (!message) return null;
    return (
      <MessageBox
        status={message.status}
        title={message.title}
        message={message.text}
      />
    );
  };

  const renderLoading = () => {
    if (!loading) return null;
    return (
      <MessageBox
        status={"Loading"}
        title={"Loading"}
        message={"Building Table..."}
      />
    );
  };

  const renderForm = () => {
    if (results.length > 0) return null;
    return (
      <Form>
        <Form.Group widths="equal">
          <Controller
            name={"project"}
            control={control}
            rules={{ required: "Required" }}
            render={({ field: { name, value } }) => (
              <Form.Select
                fluid
                search
                selection
                clearable
                name={name}
                label={"Project"}
                required={true}
                value={value}
                onChange={handleChange}
                autoComplete="off"
                options={projects.map((record) => {
                  return {
                    key: record,
                    text: record,
                    value: record,
                  };
                })}
                error={
                  errors["project"]
                    ? {
                        content: errors["project"].message,
                        pointing: "above",
                      }
                    : false
                }
              />
            )}
          />
          <Form.Field error={errors.hasOwnProperty("flight_date")}>
            <div className="calendar-input">
              <Controller
                name={"flight_date"}
                control={control}
                rules={{
                  required: "Required",
                }}
                render={({ field: { name, value } }) => (
                  <DateInput
                    closable
                    clearable
                    name={name}
                    label={"Date From"}
                    required={true}
                    value={value || ""}
                    dateFormat="MM/DD/YYYY"
                    iconPosition="left"
                    onChange={handleChange}
                    autoComplete="off"
                  />
                )}
              />
            </div>
            {errors[`flight_date`] && (
              <Label pointing prompt>
                {errors[`flight_date`].message}
              </Label>
            )}
          </Form.Field>
        </Form.Group>

        <Divider />

        <Button
          animated
          floated="right"
          primary
          loading={submitted}
          disabled={submitted}
          onClick={handleSubmit(formSubmit)}
        >
          <ButtonContent visible>Submit</ButtonContent>
          <ButtonContent hidden>
            <Icon name="arrow right" />
          </ButtonContent>
        </Button>
        <div style={{ clear: "both" }} />
      </Form>
    );
  };

  const renderResults = () => {
    if (results.length === 0) return null;
    return (
      <div className="table-overflow">
        <Table selectable unstackable celled striped>
          <Table.Header>
            <Table.Row>
              <Table.HeaderCell></Table.HeaderCell>
              <Table.HeaderCell>Upload Date</Table.HeaderCell>
              <Table.HeaderCell>Flight Date</Table.HeaderCell>
              <Table.HeaderCell>Project</Table.HeaderCell>
              <Table.HeaderCell>Frame Center Count</Table.HeaderCell>
              <Table.HeaderCell>States</Table.HeaderCell>
              <Table.HeaderCell>UTM</Table.HeaderCell>
            </Table.Row>
          </Table.Header>

          <Table.Body>
            {results.map((record) => {
              return (
                <Table.Row
                  key={record.id}
                  onClick={() => setSelected(record.id)}
                >
                  <Table.Cell collapsing>
                    <Form.Field>
                      <Radio
                        name="radioGroup"
                        value={record.id}
                        checked={selected === record.id}
                        onChange={(e, i) => i.checked && setSelected(i.value)}
                      />
                    </Form.Field>
                  </Table.Cell>
                  <Table.Cell>{record.upload_date}</Table.Cell>
                  <Table.Cell>{record.flight_date}</Table.Cell>
                  <Table.Cell>{record.project}</Table.Cell>
                  <Table.Cell>{record.fc_count}</Table.Cell>
                  <Table.Cell>{record.states}</Table.Cell>
                  <Table.Cell>{record.utm}</Table.Cell>
                </Table.Row>
              );
            })}
          </Table.Body>
        </Table>

        <Divider />

        <Button
          animated
          floated="right"
          primary
          loading={submitted}
          disabled={submitted || !selected}
          onClick={splitSubmit}
        >
          <ButtonContent visible>Submit</ButtonContent>
          <ButtonContent hidden>
            <Icon name="arrow right" />
          </ButtonContent>
        </Button>
      </div>
    );
  };

  console.log("EOSplitter", { projects, values: getValues() });

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Export</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>EO SPlitter</Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />
      {renderMessage()}
      {renderLoading()}
      {renderForm()}
      {renderResults()}
    </div>
  );
};

export default EoSplitter;
